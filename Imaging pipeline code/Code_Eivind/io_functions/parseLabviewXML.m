% Copyright 2016, Tilman Raphael Schr?der <tilman.schroeder@uni-due.de>

%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.

% This function converts XML files which have been created using the
% "Flatten To XML" and "Write to XML File" VIs into structure arrays,
% using the names of controls/variables as field names in the structure.
% It supports reading clusters, arrays, boolean values, timestamps, enums,
% integers, fixed-point numbers, floating point numbers, strings, rings and
% analog waveforms.
% Clusters and arrays can contain any of the supported types in any
% combination. Error clusters are clusters with three named elements so
% they are supported, too.
%
% All variables need to have names, except array elements. If a variable
% does not have a name the function exits with an error. Variable names
% need to be unique at their level of nesting (i.e. names of elements in a
% cluster must be unique). Variable names are converted to legal structure
% field names (but this conversion is not complete/optimal yet).
% 
% Integers are imported in their correct type, i.e. a control of type
% I8/I16/I32/I64/U8/U16/U32/U64 is imported as int8/int16/int32/int64/
% uint8/uint16/uint32/uint64.
%
% Floating-point numbers are imported as double precision floats if possible.
% This is the case for both real and complex single and double precision
% floating point numbers. Extended precision real and complex
% floating-point numbers are imported as strings because there is no
% numeric equivalent in MATLAB?. Fixed-point numbers are imported as a
% structure which contains word and integer length as doubles, the signed
% flag as logical, value, minimum and maximum as structs containing a
% negative flag as logical and the value as a uint64 (independend of the
% negative flag value). The fixed-point struct contains another struct in
% the field "Delta" which contains word length, integer length and value as
% above. Overflow status is not exported by the "Flatten To XML" VI and
% therefore cannot be imported.
%
% Boolean values are imported as logicals.
%
% Timestamps are converted to datetime structures with TimeZone set to UTC.
% Please note that during this conversion precision is lost because the
% datetime structure cannot resolve the attosecond precision of LabVIEW?
% timestamps.
% 
% Text/menu rings are imported as their representation since the "Flatten
% To XML" VI does not include the Item value in the XML file.
%
% Enums are imported as a string containing the selected item.
%
% LvVariant entries are imported as a cell array of strings, the contents
% of this type of entry is not interpreted (yet).
%
% Clusters are imported as structs containing their elements as fields with
% the element name being the field name.
%
% Arrays are imported as either cell or ordinary array, depending on the
% type of elements the array contains: Single and double precision real and
% complex floating point numbers, all integer types and logicals are
% converted to ordinary arrays. All numbers of dimensions are supported.
% Arrays can contain all other supported data types.
%
% Strings are imported as a character array if the string is a single line
% or as a cell array (column vector) of character arrays if the string has
% multiple lines.
%
% Paths are handled as strings.
%
% Analog waveforms are essentially clusters and are imported as such. They
% contain a timestamp in field "t0", a double precision floating point
% number in the field "dt", an array named "Y", an error cluster in the
% field "error" and an LvVariant named "attributes". All possible data
% types of the "Y" array elements are supported.
%
% Digital waveforms are not supported. Feel free to add this functionality!
%
% For now, the XML file must start with the two lines
%	<?xml version='1.0' standalone='yes' ?>
%	<LVData xmlns="http://www.ni.com/LVData">
% followed by a <Version> tag and end with the line
%	</LVData>
% These lines are created by the "Write to XML File" VI.
%
% Example XML files and VIs are still missing.
%
% This function is MUCH faster than using the xmlread function!
% 
% Tested with LabVIEW? software version 12.0.1f5 and
% MATLAB? version R2016a/9.0.
% 
% MATLAB is a registered trademark of The MathWorks, Inc.,
% LabVIEW is a trademark of National Instruments.

function LabviewXmlStruct = parseLabviewXML(filepath)
	[ fileId, errmsg ] = fopen(filepath, 'r');
	assert(fileId >= 1, errmsg);
	assert(strcmp(fgetl(fileId), '<?xml version=''1.0'' standalone=''yes'' ?>'));
	assert(strcmp(fgetl(fileId), '<LVData xmlns="http://www.ni.com/LVData">'));
	
	Version = convertSpecialChars(parseTag(fgetl(fileId), fileId, '<Version>', '</Version>'));
	
	LabviewXmlStruct = addToStruct('Version', Version, struct());
	[ name, value ] = parseBlock(fgetl(fileId), fileId);
	
	LabviewXmlStruct = addToStruct(name, value, LabviewXmlStruct);
	assert(strcmp(fgetl(fileId), '</LVData>'));
	fclose(fileId);
end

function tagValue = parseTag(line, fileId, startTag, endTag)
	assert(strncmp(line, startTag, numel(startTag)));
	line = line((numel(startTag) + 1):end); % remove start tag
	tagValue = cell(0, 1);
	i = 1;
	while ~strncmp(fliplr(line), fliplr(endTag), numel(endTag)),
		tagValue{i, 1} = line;
		line = fgetl(fileId);
		i = i + 1;
	end
	tagValue{i, 1} = line(1:(numel(line) - numel(endTag)));
	if isscalar(tagValue),
		tagValue = tagValue{1};
	end
end

function val = parseValTag(fileId)
	val = parseTag(fgetl(fileId), fileId, '<Val>', '</Val>');
end

function name = parseNameTag(fileId)
	name = convertSpecialChars(parseTag(fgetl(fileId), fileId, '<Name>', '</Name>'));
end

function NumElts = parseNumEltsTag(fileId)
	NumElts = str2double(parseTag(fgetl(fileId), fileId, '<NumElts>', '</NumElts>'));
end

function [ name, value ] = parseBlock(line, fileId)
	floatTypes = { '<SGL>', '<DBL>', '<CSG>', '<CDB>' };
	integerTypes = { '<I8>', '<I16>', '<I32>', '<I64>', '<U8>', '<U16>', '<U32>', '<U64>' };
	booleanType = { '<Boolean>' };
	cell2matTypes = [ floatTypes, integerTypes, booleanType ];
	% extended floating point (real and complex) vars are imported as
	% strings because there is no Matlab equivalent data type
	stringTypes = { '<String>', '<EXT>', '<CXT>', '<Path>' };
	waveformTypes = {	'<SGLWaveform>', ...
						'<DBLWaveform>', ...
						'<EXTWaveform>', ...
						'<CSGWaveform>', ...
						'<CDBWaveform>', ...
						'<CXTWaveform>', ...
						'<I8Waveform>', ...
						'<I16Waveform>', ...
						'<I32Waveform>', ...
						'<I64Waveform>', ...
						'<U8Waveform>', ...
						'<U16Waveform>', ...
						'<U32Waveform>', ...
						'<U64Waveform>'};
	switch line,
		case '<Cluster>',
			[ name, value ] = parseClusterBlock(fileId);
		case floatTypes,
			[ name, value ] = parseFloatBlock(fileId, line);
		case '<FXP>',
			[ name, value ] = parseFixedBlock(fileId);
		case booleanType,
			[ name, value ] = parseBooleanBlock(fileId);
		case integerTypes,
			[ name, value ] = parseIntegerBlock(fileId, line);
		case stringTypes,
			[ name, value ] = parseStringBlock(fileId, line);
		case '<Array>',
			[ name, value ] = parseArrayBlock(fileId, cell2matTypes);
		case waveformTypes,
			[ name, value ] = parseWaveformBlock(fileId, line);
		case '<Timestamp>',
			[ name, value ] = parseTimestampBlock(fileId);
		case '<LvVariant>',
			[ name, value ] = parseLvVariantBlock(fileId);
		case '<EW>',
			[ name, value ] = parseEwBlock(fileId);
		otherwise,
			error(['Unknown tag ''', line, '''!']);
	end
end

function [ name, value ] = parseClusterBlock(fileId)
	name = parseNameTag(fileId);
	NumElts = parseNumEltsTag(fileId);
	value = struct();
	line = fgetl(fileId);
	i = 0;
	while ~strcmp(line, '</Cluster>'),
		i = i + 1;
		[ thisElementName, thisElementValue ] = parseBlock(line, fileId);
		value = addToStruct(thisElementName, thisElementValue, value);
		line = fgetl(fileId);
	end
	assert(i == NumElts);
end

function [ name, value ] = parseFloatBlock(fileId, type)
	name = parseNameTag(fileId);
	value = str2double(parseValTag(fileId));
	assert(strcmp(fgetl(fileId), [ '</', type(2:end) ]));
end

function [ name, value ] = parseFixedBlock(fileId)
	name = parseNameTag(fileId);
	% word length is between 1 and 64 bit.
	wordLength = str2double(parseTag(fgetl(fileId), fileId, '<WordLength>', '</WordLength>'));
	% integer length is between -1024 and +1024 bit.
	integerLength = str2double(parseTag(fgetl(fileId), fileId, '<IntegerLength>', '</IntegerLength>'));
	if strcmp(parseTag(fgetl(fileId), fileId, '<Sign>', '</Sign>'), 'Signed'),
		signed = true;
	else
		signed = false;
	end
	val = hex2decStruct(parseValTag(fileId));
	minimum = hex2decStruct(parseTag(fgetl(fileId), fileId, '<Minimum>', '</Minimum>'));
	maximum = hex2decStruct(parseTag(fgetl(fileId), fileId, '<Maximum>', '</Maximum>'));
	assert(strcmp(fgetl(fileId), '<Delta>'));
	deltaWordLength = str2double(parseTag(fgetl(fileId), fileId, '<WordLength>', '</WordLength>'));
	deltaIntegerLength = str2double(parseTag(fgetl(fileId), fileId, '<IntegerLength>', '</IntegerLength>'));
	deltaVal = hex2decStruct(parseValTag(fileId));
	assert(strcmp(fgetl(fileId), '</Delta>'));
	assert(strcmp(fgetl(fileId), '</FXP>'));
	delta = struct('WordLength', deltaWordLength, 'IntegerLength', deltaIntegerLength, 'Val', deltaVal);
	value = struct(	'WordLength', wordLength, ...
					'IntegerLength', integerLength, ...
					'Sign', signed, ...
					'Val', val, ...
					'Minimum', minimum, ...
					'Maximum', maximum, ...
					'Delta', delta);
end

function [ name, value ] = parseBooleanBlock(fileId)
	name = parseNameTag(fileId);
    tempA = str2double(parseValTag(fileId));
    tempA(isnan(tempA)) = 0;
    value = logical(tempA);
	%value = logical(str2double(parseValTag(fileId)));
	assert(strcmp(fgetl(fileId), '</Boolean>'));
end

function [ name, value ] = parseIntegerBlock(fileId, type)
	name = parseNameTag(fileId);
	tagValue = parseValTag(fileId);
	if strcmp(type(2), 'U'),
		conversionFunc = 'uint';
	else
		conversionFunc = 'int';
	end
	conversionFunc = [ conversionFunc, type(3:(end - 1)) ];
	value = str2num([ conversionFunc, '(', tagValue, ')' ]);
	assert(strcmp(fgetl(fileId), [ '</', type(2:end) ]));
end

function [ name, value ] = parseStringBlock(fileId, type)
	name = parseNameTag(fileId);
	value = convertSpecialChars(parseValTag(fileId));
	assert(strcmp(fgetl(fileId), [ '</', type(2:end) ]));
end

function [ name, value ] = parseArrayBlock(fileId, cell2matTypes)
	name = parseNameTag(fileId);
	dimsizeStart = '<Dimsize>';
	dimsizeEnd   = '</Dimsize>';
	line = fgetl(fileId);
	arraySize = [ 1, 1 ];
	numDimsizeTags = 0;
	while strncmp(dimsizeStart, line, numel(dimsizeStart)),
		numDimsizeTags = numDimsizeTags + 1;
		arraySize(numDimsizeTags) = str2double(parseTag(line, fileId, dimsizeStart, dimsizeEnd));
		line = fgetl(fileId);
	end
	assert(numDimsizeTags > 0);
	numelArray = prod(arraySize(:));
	type = line;
	value = cell(arraySize);
	if numelArray > 0,
		i = 0;
		while ~strcmp(line, '</Array>'),
			i = i + 1;
			assert(strcmp(type, line));
			% in arrays, names are ignored
			[ ~, thisElementValue ] = parseBlock(line, fileId);
			value{i} = thisElementValue;
			line = fgetl(fileId);
		end
		assert(i == numelArray);
	else % empty array
		% in empty arrays, there is one block with empty Name and empty Val
		% tag
		parseBlock(line, fileId);
		assert(strcmp(fgetl(fileId), '</Array>'));
	end
	
	if any(strcmp(type, cell2matTypes)), ...
		value = cell2mat(value);
	end
end

function [ name, value ] = parseWaveformBlock(fileId, type)
	name = parseNameTag(fileId);
	assert(strcmp('<Cluster>', fgetl(fileId)));
	[ ~, value ] = parseClusterBlock(fileId);
	assert(strcmp(fgetl(fileId), [ '</', type(2:end) ]));
end

function [ name, value ] = parseTimestampBlock(fileId)
	name = parseNameTag(fileId);
	assert(strcmp('<Cluster>', fgetl(fileId)));
	parseNameTag(fileId); % name of cluster is empty, so we cannot use parseClusterBlock(fileId)
	NumElts = parseNumEltsTag(fileId);
	assert(4 == NumElts);
	I32data = zeros(1, NumElts, 'int32');
	for i = 1:NumElts,
		line = fgetl(fileId);
		assert(strcmp('<I32>', line));
		[ ~, oneTimestampI32 ] = parseIntegerBlock(fileId, line);
        %disp(I32data)
        %disp(oneTimestampI32)
		I32data(i) = oneTimestampI32;
	end

	U32data = zeros(1, 4, 'uint32');
	for I32indexNum = 1:NumElts,
		U32data(I32indexNum) = typecast(I32data(I32indexNum), 'uint32');
	end
	
	secondsAfterLabviewEpoch = typecast([U32data(3), U32data(4)], 'int64');
	%milliseconds = typecast([U32data(1), U32data(2)], 'uint64') * (2^(-64) * 1000);
	
    value = datetime(1904, 1, 1, 0, 0, secondsAfterLabviewEpoch, 'TimeZone', 'UTC', ...
                     'Format','HH:mm:ss Z');
	
    % Commented out this line because it gave an error 27/11/2016
    %value = datetime(1904, 1, 1, 0, 0, secondsAfterLabviewEpoch, milliseconds, 'TimeZone', '');
	
	assert(strcmp('</Cluster>', fgetl(fileId)));
	assert(strcmp('</Timestamp>', fgetl(fileId)));
end

function [ name, value ] = parseLvVariantBlock(fileId)
	name = parseNameTag(fileId);
	warning('LvVariant blocks are not parsed but returned as strings for now!');
	numEndTagsToFind = 1;
	value = cell(0);
	i = 0;
	while numEndTagsToFind > 0,
		line = fgetl(fileId);
		i = i + 1;
		if strcmp('</LvVariant>', line),
			numEndTagsToFind = numEndTagsToFind - 1;
		elseif strcmp('<LvVariant>', line),
			numEndTagsToFind = numEndTagsToFind + 1;
		end
		value{i, 1} = line;
	end
end

function [ name, value ] = parseEwBlock(fileId)
	name = parseNameTag(fileId);
	choiceStart = '<Choice>';
	choiceEnd   = '</Choice>';
	line = fgetl(fileId);
	choices = cell(0);
	i = 0;
	while strncmp(choiceStart, line, numel(choiceStart)),
		i = i + 1;
		choices{i} = parseTag(line, fileId, choiceStart, choiceEnd);
		line = fgetl(fileId);
	end
	assert(i > 0);
	value = convertSpecialChars(choices{str2double(parseTag(line, fileId, '<Val>', '</Val>')) + 1});
	assert(strcmp('</EW>', fgetl(fileId)));
end

function LabviewXmlStruct = addToStruct(name, value, LabviewXmlStruct)
	assert(~isfield(LabviewXmlStruct, name));
	LabviewXmlStruct.(createLegalStructFieldName(name)) = value;
end

function name = createLegalStructFieldName(name)
	name = strrep(name, ' ', '_');
	name = strrep(name, '[', '_');
	name = strrep(name, ']', '_');
	name = strrep(name, '@', '_at_');
	name = strrep(name, '-', '_dash_');
end

function str = convertSpecialChars(str)
	str = strrep(str,  '&lt;', '<');
	str = strrep(str,  '&gt;', '>');
	str = strrep(str, '&amp;', '&');
end

function decStruct = hex2decStruct(h)
	assert(ischar(h));
	assert(size(h, 1) == 1);
	h = lower(h);
	if strncmp(h, '-', 1),
		negative = true;
		h = h(2:end);
	else
		negative = false;
	end
	assert(strncmp(h, '0x', 2));
	h = h(3:end); % remove 0x
	% remove leading zeros
	[token, remain] = strtok(h, '0');
	h = [ token, remain ];

	dec = uint64(0);
	if ~isempty(h),
		length = size(h, 2);
		assert(all((h >= '0' & h <= '9') | (h >= 'a' & h <= 'f')));

		numberIndices = h <= 64; % Numbers
		h(numberIndices) = h(numberIndices) - 48;

		letterIndices =  h > 64; % Letters
		h(letterIndices) = h(letterIndices) - 97 + 10;
		
		h = cast(h, 'uint64');
		p = uint64(16).^uint64((length - 1):-1:0);
		dec = sum(h.*p , 'native');
	end
	decStruct = struct('uint64', dec, 'negative', negative);
end

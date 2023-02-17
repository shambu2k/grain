%token PARAM SECTION SINCE HISTORY THROWS RETURNS EXAMPLE DEPRECATED COLON EOL EOF
%token <string> TEXT IDENT SEMVER CONSTRUCTOR

%right EOL

%start <Comment_attributes.parsed_graindoc> graindoc

%%

eols:
  | EOL
  | eols EOL {}

multiline_text_help:
  | TEXT { [$1] }
  | multiline_text_help EOL TEXT { $3 :: "\n" :: $1 }
  | multiline_text_help eols EOL TEXT { $4 :: "\n\n" :: $1 }

%inline multiline_text:
  | rev(multiline_text_help) { String.concat "" $1 }

description:
  | { None }
  | multiline_text ioption(eols) { Some($1) }

attribute_text:
  | ioption(eols) multiline_text ioption(eols) %prec EOL { $2 }

attribute:
  | PARAM IDENT COLON attribute_text { Param({ attr_name=$2; attr_type=None; attr_desc=$4 }) }
  | RETURNS attribute_text { Returns({ attr_desc=$2; attr_type=None }) }
  | EXAMPLE attribute_text { Example({attr_desc=$2}) }
  | SECTION TEXT COLON attribute_text { Section({ attr_name=$2; attr_desc=$4; }) }
  | DEPRECATED attribute_text { Deprecated({attr_desc=$2}) }
  | SINCE SEMVER { Since({attr_version=$2}) }
  | HISTORY SEMVER COLON attribute_text { History({ attr_version=$2; attr_desc=$4; }) }
  | THROWS CONSTRUCTOR COLON attribute_text { Throws({ attr_type=Some $2; attr_desc=$4; }); }

attributes_help:
  | attribute { [$1] }
  | attributes_help option(eols) attribute { $3 :: $1 }

%inline attributes:
  | { [] }
  | rev(attributes_help) ioption(eols) { $1 }

graindoc:
  | option(eols) description attributes EOF { ($2, $3) }
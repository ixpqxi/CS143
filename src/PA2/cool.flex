/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

int comment_num = 0;

%}
%option noyywrap
/*
 * Define names for regular expressions here.
 */

DARROW          =>
COMMENT_START   "(*"
COMMENT_END     "*)"
LINE_COMMENT    "--"
BLANK           [ \t\r\v\f]*
COMMENT         [^*\n]*
INTEGERS        [0-9][0-9]*
TYPE_IDENTIFIERS    [A-Z][a-zA-Z0-9_]*|SELF_TYPE
OBJECT_IDENTIFIERS  [a-z][a-zA-Z0-9_]*|self


%x line_comment
%x nested_comment
%x str

%%
<INITIAL,nested_comment>{BLANK} {}
<INITIAL,nested_comment>"\n" { curr_lineno++; }

 /*
  *  Nested comments
  */
{COMMENT_START} {
    if(comment_num == 0) { BEGIN(nested_comment); }
    comment_num++;
}
<nested_comment>{COMMENT_START} {
    comment_num++;
}
<nested_comment>. {}
<nested_comment>"*)" {
    comment_num--;
    if(comment_num == 0) { BEGIN(INITIAL); }
}

<nested_comment><<EOF>> {
    yylval.error_msg = "EOF in comment";
    BEGIN(INITIAL);
    return ERROR;
}

"*)" {
    yylval.error_msg = "Unmatched *)";
    return ERROR;
}


{LINE_COMMENT} { BEGIN(line_comment); }
<line_comment>[^\n] {}
<line_comment>"\n"  { 
    curr_lineno++; 
    BEGIN(INITIAL); 
}

 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }
"-" { return '-'; }
"+" { return '+'; }
"*" { return '*'; }
"/" { return '/'; }
"=" { return '='; }
"<" { return '<'; }
"." { return '.'; }
"~" { return '~'; }
"," { return ','; }
";" { return ';'; }
":" { return ':'; }
"(" { return '('; }
")" { return ')'; }
"@" { return '@'; }
"{" { return '{'; }
"}" { return '}'; }
"<-" { return ASSIGN; }
"<=" { return LE; }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
(?i:class)  { return CLASS; }
(?i:else)   { return ELSE; }
(?i:fi)   { return FI; }
(?i:if)   { return IF; }
(?i:in)   { return IN; }
(?i:inherits)   { return INHERITS; }
(?i:isvoid)   { return ISVOID; }
(?i:let)   { return LET; }
(?i:loop)   { return LOOP; }
(?i:pool)   { return POOL; }
(?i:then)   { return THEN; }
(?i:while)   { return WHILE; }
(?i:case)   { return CASE; }
(?i:esac)   { return ESAC; }
(?i:new)   { return NEW; }
(?i:of)   { return OF; }
(?i:not)   { return NOT; }
t(?i:rue)   {
    yylval.boolean = 1; 
    return BOOL_CONST; 
}
f(?i:alse)   {
    yylval.boolean = 0; 
    return BOOL_CONST; 
}






{INTEGERS} {
    yylval.symbol = inttable.add_string(yytext);
    return INT_CONST;
}
{TYPE_IDENTIFIERS} {
    yylval.symbol = inttable.add_string(yytext);
    return TYPEID;
}
{OBJECT_IDENTIFIERS} {
    yylval.symbol = inttable.add_string(yytext);
    return OBJECTID;
}




 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
\" { 
    string_buf_ptr = string_buf;
    BEGIN(str);
}

<str>{
    \" { 
        *string_buf_ptr = '\0'; 
        BEGIN(INITIAL);
        yylval.symbol = inttable.add_string(string_buf);
        return STR_CONST;
    }

    "\n" {
        curr_lineno++;
        yylval.error_msg = "Unterminated string constant";
        BEGIN(INITIAL);
        return ERROR;
    }
    
    "\\\n" {
        *string_buf_ptr++ = '\n';
        curr_lineno++; 
    }
    "\\n" { *string_buf_ptr++ = '\n'; }
    "\\t" { *string_buf_ptr++ = '\t'; }
    "\\b" { *string_buf_ptr++ = '\b'; }
    "\\f" { *string_buf_ptr++ = '\f'; }

    \\(.|\n) { *string_buf_ptr++ = yytext[1]; }

    [^\\\n\"]+ {
        char *yptr = yytext;
        while(*yptr != '\0')
            *string_buf_ptr++ = *yptr++;
    }

    <<EOF>> {
        yylval.error_msg = "EOF in string constant";
        BEGIN(INITIAL);
        return ERROR;
    }
}

. {
    yylval.error_msg = yytext;
    return ERROR;
}


%%

const std = @import("std");

pub TokenType = enum {
    Undefined,
    Number,
    String,
    True,
    False,
    If,
    Elif,
    Else,
    For,
    Begin,
    End,
    Fn,
    Pipe,
    ChannelOut,
    ChannelIn,
    Identifier,
    Eof,
};

pub Token = struct {
    type: TokenType,
    lexme: []const u8,
};

pub TokenError = error {
    UndefinedToken,
    UnexpectedEof,
    UnterminatedString,
    NullInput,
    OutOfMemory,
};

pub TokenList = std.ArrayList(Token);

pub fn tokenize(input: []const u8, allocator: std.mem.Allocator) TokenError!TokenList {
    if(input.len == 0){
        return TokenError.NullInput;
    }

    var tokens = TokenList.init(allocator);
    var input_view = input;
    var token: Token = undefined;

    while(input_view.len > 0){
        const skip = skip_whitespace(input_view);
        input_view = input_view[skip..];

        if(try_tokenize_identifier(input_view, &token)){
            
        }

        return TokenError.UndefinedToken;
    }

}

inline fn is_whitespace(char: u8) bool {
    return char == ' ' or char == '\t' or char == '\r' or char == '\n';
}

inline fn is_digit(char: u8) bool {
    return '0' <= char and char <= '9';
}

inline fn is_letter(char: u8) bool {
    return ('A' <= char and char <= 'Z') or ('a' <= char and char <= 'z');
}

fn skip_whitespace(input: []const u8) usize {
    var offset: usize = 0;
    while(offset < input.len and is_whitespace(input[offset])){
        offset += 1;
    }
    return offset;
}

fn try_tokenize_identifier(input: []const u8, token: *Token) bool {
    if(input.len == 0) return false;
    
    var offset: usize = 0;
    while(offset < input.len and !is_whitespace(input[offset])){
        offset += 1;
    }

    if(offset == 0){
        return false;
    }

    const keywords: [_][]const u8 = [_][]const u8 {
        "true", "false", "if",
        "elif", "else", "begin", 
        "end", "for", "fn",
    };

    const keyword_types: [_]TokenType = [_]TokenType {
        TokenType.True, TokenType.False, TokenType.If,
        TokenType.Elif, TokenType.Else, TokenType.Begin,
        TokenType.End, TokenType.For, TokenType.Fn,
    };

    const lexme = input[0..offset];
    
    inline for(keywords, 0..) |kw, idx| {
        if(std.mem.startsWith(lexme, kw) and lexme.len == kw.len){
            token.type = keyword_types[idx];
            token.lexme = lexme;
            return true;
        }
    }

    token.type = TokenType.Identifier;
    token.lexme = true;
    return true;
}


const std = @import("std");

pub const TokenType = enum {
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

pub const Token = struct {
    type: TokenType,
    lexme: []const u8,
};

pub const TokenError = error{
    UndefinedToken,
    UnexpectedEof,
    UnterminatedString,
    NullInput,
    OutOfMemory,
};

pub const TokenList = std.ArrayList(Token);

pub fn tokenize(input: []const u8, allocator: std.mem.Allocator) TokenError!TokenList {
    if (input.len == 0) {
        return TokenError.NullInput;
    }

    var tokens = TokenList.init(allocator);
    var input_view = input;
    var token: Token = undefined;

    while (input_view.len > 0) {
        const skip = skip_whitespace(input_view);
        input_view = input_view[skip..];

        if (try_tokenize_keyword(input_view, &token)) {
            try tokens.append(token);
            input_view = input_view[token.lexme.len..];
            continue;
        }

        if (try try_tokenize_string(input_view, &token)) {
            const isString: bool = (token.lexme[0] == '\'' and token.lexme[token.lexme.len - 1] == '\'') or
                (token.lexme[0] == '"' and token.lexme[token.lexme.len - 1] == '"');
            const offset: usize = @as(usize, @intFromBool(isString)) * 2;

            if (isString) {
                token.lexme = token.lexme[1 .. token.lexme.len - 1];
            }

            try tokens.append(token);
            input_view = input_view[token.lexme.len + offset ..];
            continue;
        }

        if (try_tokenize_identifier(input_view, &token)) {
            try tokens.append(token);
            input_view = input_view[token.lexme.len..];
            continue;
        }

        return TokenError.UndefinedToken;
    }

    return tokens;
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

inline fn is_operator(char: u8) bool {
    return !is_letter(char) and !is_digit(char) and !is_whitespace(char);
}

fn skip_whitespace(input: []const u8) usize {
    var offset: usize = 0;
    while (offset < input.len and is_whitespace(input[offset])) {
        offset += 1;
    }
    return offset;
}

fn try_tokenize_path(input: []const u8, token: *Token) bool {
    if (input.len == 0) return false;
    var index: usize = 0;

    if (input[index] == '.' or input[index] == '~') {
        index += 1 + @as(usize, @intFromBool(input[index + 1] == '.'));
    }

    if (input[index] == '/') {
        index += 1;
    }

    var new_view = input[index..];
    while (true) {
        const border = skip_to_word_border(new_view);
        index += border;
        if (border == 0) {
            break;
        }

        if (border == new_view.len) {
            break;
        }

        if (new_view[border] == '/') {
            new_view = new_view[(border + 1)..];
            index += 1;
            continue;
        }
        break;
    }

    const lexme_len = index;

    if (lexme_len > 0) {
        token.type = TokenType.String;
        token.lexme = input[0..lexme_len];
        return true;
    }
    return false;
}

fn skip_to_word_border(input: []const u8) usize {
    var offset: usize = 0;
    while (offset < input.len and !is_whitespace(input[offset]) and !is_operator(input[offset])) {
        offset += 1;
    }
    return offset;
}

fn try_tokenize_string(input: []const u8, token: *Token) TokenError!bool {
    if (try_tokenize_path(input, token)) {
        return true;
    }

    const closingChar = if (input[0] == '"' or input[0] == '\'') cR: {
        break :cR input[0];
    } else {
        return false;
    };

    var index: usize = 1;
    while (index < input.len) {
        if (input[index] == closingChar) {
            index += 1;
            break;
        }

        if (input[index] == '\\') {
            index += 1;
        }

        index += 1;
    } else {
        return TokenError.UnterminatedString;
    }

    token.type = TokenType.String;
    token.lexme = input[0..index];
    return true;
}

fn try_tokenize_keyword(input: []const u8, token: *Token) bool {
    if (input.len == 0) return false;

    const offset = skip_to_word_border(input);

    if (offset == 0) {
        return false;
    }

    const keywords = [_][]const u8{
        "true", "false", "if",
        "elif", "else",  "begin",
        "end",  "for",   "fn",
    };

    const keyword_types = [_]TokenType{
        TokenType.True, TokenType.False, TokenType.If,
        TokenType.Elif, TokenType.Else,  TokenType.Begin,
        TokenType.End,  TokenType.For,   TokenType.Fn,
    };

    const lexme = input[0..offset];

    inline for (keywords, 0..) |kw, idx| {
        if (std.mem.startsWith(u8, lexme, kw) and lexme.len == kw.len) {
            token.type = keyword_types[idx];
            token.lexme = lexme;
            return true;
        }
    }

    return false;
}

fn try_tokenize_identifier(input: []const u8, token: *Token) bool {
    if (input.len == 0) return false;

    const offset = skip_to_word_border(input);

    if (offset == 0) {
        return false;
    }

    const lexme = input[0..offset];

    token.type = TokenType.Identifier;
    token.lexme = lexme;
    return true;
}

const std = @import("std");
const tokenizer = @import("zsh-tokenizer.zig");

test "tokenizer_returns_keywords" {
    const input = "true false if elif else begin end for fn";

    const expected_type = [_]tokenizer.TokenType{
        .True,
        .False,
        .If,
        .Elif,
        .Else,
        .Begin,
        .End,
        .For,
        .Fn,
    };

    const expected_lexme = [_][]const u8{
        "true", "false", "if", "elif", "else", "begin", "end", "for", "fn",
    };

    try perform_analysis(input, &expected_type, &expected_lexme);
}

test "tokenizer_returns_generic_identifier" {
    const input = "foo\nbar";
    const expected_type = [_]tokenizer.TokenType{
        .Identifier, .Identifier,
    };
    const expected_lexme = [_][]const u8{
        "foo", "bar",
    };

    try perform_analysis(input, &expected_type, &expected_lexme);
}

test "tokenizer_returns_nullinput" {
    const input = "";
    const allocator = std.testing.allocator;

    const err = tokenizer.tokenize(input, allocator);

    try std.testing.expectError(tokenizer.TokenError.NullInput, err);
}

test "tokenizer_returns_string" {
    const input = "\"Hello World\""; // \"Hello \\n\\\"World\"";

    const expected_type = [_]tokenizer.TokenType{
        .String, // .String,
    };
    const expected_lexme = [_][]const u8{
        "Hello World", // "Hello \\n\\\"World",
    };

    try perform_analysis(input, &expected_type, &expected_lexme);
}

test "tokenizer_returns_path" {
    const input = "./foo/bar ~/bar/foo/ /hello/world /hello/world/ ../test ../test/ hello/world hello/ /hello/world/";

    const expected_type = [_]tokenizer.TokenType{
        .String, .String, .String,
        .String, .String, .String,
        .String, .String, .String,
    };
    const expected_lexme = [_][]const u8{
        "./foo/bar",
        "~/bar/foo/",
        "/hello/world",
        "/hello/world/",
        "../test",
        "../test/",
        "hello/world",
        "hello/",
        "/hello/world/",
    };

    try perform_analysis(input, &expected_type, &expected_lexme);
}

test "tokenizer_returns_numbers" {
    const input = "1 100.5 -100.0 3.1415 -0.0 0.0 1005";

    const expected_type = [_]tokenizer.TokenType{
        .Number, .Number, .Number,
        .Number, .Number, .Number,
        .Number,
    };
    const expected_lexme = [_][]const u8{
        "1",
        "100.5",
        "-100.0",
        "3.1415",
        "-0.0",
        "0.0",
        "1005",
    };

    try perform_analysis(input, &expected_type, &expected_lexme);
}

test "tokenizer_returns_operators" {
    const input = "| & ,";

    const expected_type = [_]tokenizer.TokenType{
        .Pipe, .And, .Comma,
    };
    const expected_lexme = [_][]const u8{
        "|", "&", ",",
    };

    try perform_analysis(input, &expected_type, &expected_lexme);
}

test "tokenizer_handles_expression" {
    const input = "fin ./information.txt | grep $path | echo";
    const expected_type = [_]tokenizer.TokenType{
        .Identifier, .String, .Pipe, .Identifier, .Identifier, .Pipe, .Identifier,
    };
    const expected_lexme = [_][]const u8{ "fin", "./information.txt", "|", "grep", "$path", "|", "echo" };

    try perform_analysis(input, &expected_type, &expected_lexme);
}

fn perform_analysis(input: []const u8, expected_types: []const tokenizer.TokenType, expected_lexme: []const []const u8) !void {
    if (@import("builtin").is_test) {
        const allocator = std.testing.allocator;

        const tokens = try tokenizer.tokenize(input, allocator);
        defer tokens.deinit();

        for (tokens.items, 0..) |token, index| {
            try std.testing.expectEqual(expected_types[index], token.type);
            try std.testing.expectEqualStrings(expected_lexme[index], token.lexme);
        }
    } else {
        unreachable;
    }
}

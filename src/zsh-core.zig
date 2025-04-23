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

    const allocator = std.testing.allocator;

    const tokens = try tokenizer.tokenize(input, allocator);
    defer tokens.deinit();

    for (tokens.items, 0..) |token, index| {
        try std.testing.expectEqual(expected_type[index], token.type);
        try std.testing.expectEqualStrings(expected_lexme[index], token.lexme);
    }
}

test "tokenizer_returns_generic_identifier" {
    const input = "foo\nbar";
    const expected_type = [_]tokenizer.TokenType{
        .Identifier, .Identifier,
    };
    const expected_lexme = [_][]const u8{
        "foo", "bar",
    };

    const allocator = std.testing.allocator;

    const tokens = try tokenizer.tokenize(input, allocator);
    defer tokens.deinit();

    for (tokens.items, 0..) |token, index| {
        try std.testing.expectEqual(expected_type[index], token.type);
        try std.testing.expectEqualStrings(expected_lexme[index], token.lexme);
    }
}

test "tokenizer_returns_nullinput" {
    const input = "";
    const allocator = std.testing.allocator;

    const err = tokenizer.tokenize(input, allocator);

    try std.testing.expectError(tokenizer.TokenError.NullInput, err);
}

test "tokenizer_returns_string" {
    const input = "\"Hello World\""; // \"Hello \\n\\\"World\"";
    const allocator = std.testing.allocator;

    const expected_type = [_]tokenizer.TokenType{
        .String, // .String,
    };
    const expected_lexme = [_][]const u8{
        "Hello World", // "Hello \\n\\\"World",
    };

    const tokens = try tokenizer.tokenize(input, allocator);
    defer tokens.deinit();

    for (tokens.items, 0..) |token, index| {
        try std.testing.expectEqual(expected_type[index], token.type);
        try std.testing.expectEqualStrings(expected_lexme[index], token.lexme);
    }
}

test "tokenizer_returns_path" {
    const input = "./foo/bar ~/bar/foo/ /hello/world /hello/world/ ../test ../test/ hello/world hello/ /hello/world/";
    const allocator = std.testing.allocator;

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

    const tokens = try tokenizer.tokenize(input, allocator);
    defer tokens.deinit();

    for (tokens.items, 0..) |token, index| {
        try std.testing.expectEqual(expected_type[index], token.type);
        try std.testing.expectEqualStrings(expected_lexme[index], token.lexme);
    }
}

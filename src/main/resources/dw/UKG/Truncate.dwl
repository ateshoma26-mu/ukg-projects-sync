%dw 2.0

/** UKG project descriptions are capped at 44 characters. */
fun truncate44(s: String | Null): String | Null =
    if (s == null) null
    else if (sizeOf(s) <= 44) s
    else s[0 to 43]

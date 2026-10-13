%dw 2.0
import * from dw::UKG::Truncate

/** Collapse whitespace runs and trim. */
fun sanitizeDescription(s: String | Null): String | Null =
    if (s == null) null else trim(s replace /\s+/ with " ")

/** Description written to UKG: sanitize, truncate to 44, trim again. */
fun ukgDescription(s: String | Null): String | Null =
    if (s == null) null else trim(truncate44(sanitizeDescription(s)))

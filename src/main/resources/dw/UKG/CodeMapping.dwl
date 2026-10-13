%dw 2.0

/** Sage keys have dashes/spaces; UKG codes don't. Remove both. One-way only. */
fun sageKeyToUkgCode(key: String | Null): String | Null =
    if (key == null) null else (key replace /[- ]/ with "")

/** Group Sage activities by their UKG code for one-lookup matching. */
fun activitiesByUkgCode(activities: Array<Object>): Object =
    (activities filter ($.key != null)) groupBy (a) -> sageKeyToUkgCode(a.key)

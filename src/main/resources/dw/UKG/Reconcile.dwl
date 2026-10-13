%dw 2.0
import * from dw::UKG::Sanitize
import * from dw::UKG::Truncate

/** Prefix for inactive/missing Sage activities. All caps, trailing space. */
var DO_NOT_USE_PREFIX = "DO NOT USE "

/** Idempotent do-not-use marker, cut to 44 chars. */
fun markDoNotUse(description: String | Null): String = do {
    var current = description default ""
    ---
    if (current startsWith trim(DO_NOT_USE_PREFIX)) current
    else trim(truncate44(DO_NOT_USE_PREFIX ++ current))
}

/** Index UKG projects by code for one-lookup matching. Codes are keyed as strings
 *  so a numeric code from UKG still matches; projects without a code are skipped. */
fun projectsByCode(projects: Array<Object>): Object =
    (projects filter ($.code != null)) groupBy (p) -> p.code as String

/** UKG POST bodies for Sage activities whose code is not in UKG yet. */
fun projectsToCreate(projects: Array<Object>, activitiesByCode: Object): Array<Object> = do {
    var existing = projectsByCode(projects)
    ---
    (activitiesByCode pluck (acts, code) -> { code: code as String, description: ukgDescription(acts[0].value) })
        filter (p) -> existing[p.code] == null
}

/** UKG PUT body when the description should change, else null.
 *  active Sage activity -> Sage name;  no match -> "DO NOT USE " + current */
fun reconcileProject(project: Object, activitiesByCode: Object): Object | Null =
    if (project.code == null) null
    else do {
        var activity = activitiesByCode[project.code as String][0]
        var expected =
            if (activity == null) markDoNotUse(project.description)
            else ukgDescription(activity.value)
        ---
        if (expected == null or project.description == expected) null
        else { code: project.code, description: expected }
    }

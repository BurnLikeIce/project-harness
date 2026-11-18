# Print one distinct destination per line. Run in the C locale for URL bytes.
function emit(value,    clean, byte) {
    sub(/#.*/, "", value)
    if (value == "") return
    if (value !~ /^[A-Za-z][A-Za-z0-9+.-]*:/ && value !~ /^\/\//) {
        gsub(/\\\(/, "(", value)
        gsub(/\\\)/, ")", value)
        clean = ""
        while (match(value, /%[0-9a-fA-F][0-9a-fA-F]/)) {
            clean = clean substr(value, 1, RSTART-1)
            byte = tolower(substr(value, RSTART+1, 2))
            clean = clean sprintf("%c", (index(hex,substr(byte,1,1))-1)*16 + index(hex,substr(byte,2,1))-1)
            value = substr(value, RSTART+3)
        }
        value = clean value
    }
    if (!seen[value]++) print value
}
BEGIN { hex = "0123456789abcdef" }
{
    sub(/\r$/, "")
    line = $0
    if (match(line, /^ ? ? ?(```+|~~~+)/)) {
        mark = substr(line, 1, RLENGTH)
        sub(/^ */, "", mark)
        if (!fence) fence = mark
        else if (index(mark, fence) == 1 && substr(line, RLENGTH+1) ~ /^[[:space:]]*$/) fence = ""
        next
    }
    if (fence) next
    if (line ~ /^[[:space:]]*<!-- project-harness:managed:start -->[[:space:]]*$/) { managed=1; next }
    if (line ~ /^[[:space:]]*<!-- project-harness:managed:end -->[[:space:]]*$/) { managed=0; next }
    if (managed && match(line, /^[[:space:]]*-[[:space:]]*(Tasks|Decisions|Product|Architecture|API( 契约)?|Acceptance|Handoff|任务记录|决策记录|产品事实|架构事实|验收依据|主控交接)[[:space:]]*(:|：)[[:space:]]*/)) {
        path = substr(line, RLENGTH+1)
        sub(/[[:space:]]+$/, "", path)
        sub(/^`/, "", path)
        sub(/`$/, "", path)
        if (path != "" && path != "(not mapped)" && path !~ /^\[/ && !seen[path]++) print path
    }
    # Consume code spans and complete links so link examples inside code stay literal.
    while (match(line, /`+[^`]*`+|!?\[(\\.|[^]\\])*\]\([[:space:]]*(<[^>]+>|(\\.|[^[:space:]()\\]|\([^()]*\))+)([[:space:]]+["'][^)]*)?[[:space:]]*\)/)) {
        token = substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART+RLENGTH)
        if (substr(token,1,1) != "[") continue
        sub(/^\[(\\.|[^]\\])*\]\([[:space:]]*/, "", token)
        if (substr(token,1,1) == "<") {
            sub(/^</, "", token)
            sub(/>.*/, "", token)
        } else {
            sub(/\)$/, "", token)
            sub(/[[:space:]].*$/, "", token)
        }
        emit(token)
    }
}

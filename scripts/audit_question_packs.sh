#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pack_dir="$repo_root/PesVres/TapTen/Resources/QuestionPacks"

if ! command -v jq >/dev/null 2>&1; then
    echo "[FAIL] jq is required but not installed."
    exit 1
fi

shopt -s nullglob
pack_files=("$pack_dir"/*.json)
if ((${#pack_files[@]} == 0)); then
    echo "[FAIL] No JSON pack files found in $pack_dir"
    exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

question_rows="$tmp_dir/questions.tsv"
prompt_rows="$tmp_dir/prompts.tsv"
free_coverage_rows="$tmp_dir/free_coverage.tsv"
premium_coverage_rows="$tmp_dir/premium_coverage.tsv"
touch "$question_rows" "$prompt_rows"

errors=0

report_question_ids() {
    local file="$1"
    local jq_filter="$2"
    jq -r "$jq_filter" "$file"
}

echo "== Pack Integrity Audit =="
echo "Packs: ${#pack_files[@]}"
echo

for file in "${pack_files[@]}"; do
    filename="$(basename "$file")"

    if ! jq -e . "$file" >/dev/null 2>&1; then
        echo "[FAIL] $filename: invalid JSON"
        ((errors += 1))
        continue
    fi

    pack_access="$(jq -r '(.monetization.access // "free")' "$file")"
    pack_title="$(jq -r '.title // ""' "$file")"

    invalid_answer_count_ids="$(report_question_ids "$file" '.questions[] | select((.answers | length) != 10) | .id')"
    if [[ -n "$invalid_answer_count_ids" ]]; then
        echo "[FAIL] $filename: questions without exactly 10 answers:"
        while IFS= read -r id; do
            [[ -n "$id" ]] && echo "  - $id"
        done <<< "$invalid_answer_count_ids"
        ((errors += 1))
    fi

    invalid_points_ids="$(
        report_question_ids "$file" '
            [
                .questions[]
                | .id as $qid
                | .answers[]
                | select((.points | type) != "number" or .points < 1 or .points > 5)
                | $qid
            ] | unique[]?
        '
    )"
    if [[ -n "$invalid_points_ids" ]]; then
        echo "[FAIL] $filename: answer points outside 1...5:"
        while IFS= read -r id; do
            [[ -n "$id" ]] && echo "  - $id"
        done <<< "$invalid_points_ids"
        ((errors += 1))
    fi

    score_mismatch_ids="$(
        report_question_ids "$file" '
            .questions[]
            | select(.difficultyScore != (.answers | map(.points) | add))
            | .id
        '
    )"
    if [[ -n "$score_mismatch_ids" ]]; then
        echo "[FAIL] $filename: difficultyScore does not match answer-point sum:"
        while IFS= read -r id; do
            [[ -n "$id" ]] && echo "  - $id"
        done <<< "$score_mismatch_ids"
        ((errors += 1))
    fi

    tier_mismatch_ids="$(
        report_question_ids "$file" '
            .questions[]
            | (.difficultyScore // -1) as $score
            | (
                if ($score >= 12 and $score <= 18) then "easy"
                elif ($score >= 19 and $score <= 26) then "medium"
                elif ($score >= 27 and $score <= 35) then "hard"
                else "invalid"
                end
              ) as $expectedTier
            | select(.difficultyTier != $expectedTier)
            | .id
        '
    )"
    if [[ -n "$tier_mismatch_ids" ]]; then
        echo "[FAIL] $filename: difficultyTier does not match score band:"
        while IFS= read -r id; do
            [[ -n "$id" ]] && echo "  - $id"
        done <<< "$tier_mismatch_ids"
        ((errors += 1))
    fi

    jq -r --arg file "$filename" --arg access "$pack_access" --arg title "$pack_title" '
        .questions[]
        | [
            $file,
            $access,
            $title,
            .id,
            .category,
            .difficultyTier,
            (.prompt | tostring)
        ]
        | @tsv
    ' "$file" >> "$question_rows"

    jq -r --arg file "$filename" --arg access "$pack_access" --arg title "$pack_title" '
        .questions[]
        | [
            $file,
            $access,
            $title,
            .id,
            (.prompt | ascii_downcase | gsub("[^a-z0-9]+"; " ") | gsub("^ +| +$"; ""))
          ]
        | @tsv
    ' "$file" >> "$prompt_rows"
done

duplicate_prompt_count="$(
    awk -F'\t' '
        NF >= 5 {
            key = $5
            if (key == "") {
                next
            }
            count[key]++
            refs[key] = refs[key] sprintf(" %s:%s", $1, $4)
        }
        END {
            c = 0
            for (key in count) {
                if (count[key] > 1) {
                    c++
                }
            }
            print c
        }
    ' "$prompt_rows"
)"

if [[ "$duplicate_prompt_count" != "0" ]]; then
    echo "[FAIL] Duplicate prompts found across packs:"
    awk -F'\t' '
        NF >= 5 {
            key = $5
            if (key == "") {
                next
            }
            count[key]++
            refs[key] = refs[key] sprintf(" %s:%s", $1, $4)
        }
        END {
            for (key in count) {
                if (count[key] > 1) {
                    printf "  - \"%s\" ->%s\n", key, refs[key]
                }
            }
        }
    ' "$prompt_rows" | sort
    ((errors += 1))
fi

awk -F'\t' '
    $2 == "free" && NF >= 6 {
        category = $5
        tier = $6
        total[category]++
        tierCounts[category SUBSEP tier]++
    }
    END {
        for (category in total) {
            printf "%s\t%d\t%d\t%d\t%d\n",
                category,
                total[category],
                tierCounts[category SUBSEP "easy"] + 0,
                tierCounts[category SUBSEP "medium"] + 0,
                tierCounts[category SUBSEP "hard"] + 0
        }
    }
' "$question_rows" | sort > "$free_coverage_rows"

awk -F'\t' '
    $2 == "premium" && NF >= 6 {
        key = $1 SUBSEP $3
        total[key]++
        tierCounts[key SUBSEP $6]++
    }
    END {
        for (key in total) {
            split(key, parts, SUBSEP)
            printf "%s\t%s\t%d\t%d\t%d\t%d\n",
                parts[1],
                parts[2],
                total[key],
                tierCounts[key SUBSEP "easy"] + 0,
                tierCounts[key SUBSEP "medium"] + 0,
                tierCounts[key SUBSEP "hard"] + 0
        }
    }
' "$question_rows" | sort > "$premium_coverage_rows"

declare -a final_categories=(
    "Everyday Life"
    "Food & Drink"
    "Film & TV"
    "Music"
    "Sport"
    "Geography"
    "History"
    "Science"
    "Technology"
    "Travel"
    "Work & School"
    "Pop Culture & Trends"
)

is_final_category() {
    local candidate="$1"
    local expected=""
    for expected in "${final_categories[@]}"; do
        if [[ "$candidate" == "$expected" ]]; then
            return 0
        fi
    done
    return 1
}

echo "== Free Starter Library Coverage =="
for category in "${final_categories[@]}"; do
    counts="$(
        awk -F'\t' -v c="$category" '
            $1 == c {
                printf "%d\t%d\t%d\t%d", $2, $3, $4, $5
                found = 1
            }
            END {
                if (!found) {
                    printf "0\t0\t0\t0"
                }
            }
        ' "$free_coverage_rows"
    )"

    IFS=$'\t' read -r total easy medium hard <<< "$counts"
    echo "- $category: $total total ($easy easy, $medium medium, $hard hard)"

    if [[ "$total" -ne 30 || "$easy" -ne 10 || "$medium" -ne 10 || "$hard" -ne 10 ]]; then
        echo "  [FAIL] Expected 30 total and 10/10/10 distribution."
        ((errors += 1))
    fi
done
echo

unexpected_categories="$(
    awk -F'\t' '{print $1}' "$free_coverage_rows" | sort -u
)"
while IFS= read -r category; do
    [[ -z "$category" ]] && continue
    if ! is_final_category "$category"; then
        echo "[FAIL] Unexpected free-starter category found in packs: $category"
        ((errors += 1))
    fi
done <<< "$unexpected_categories"

premium_pack_count="$(wc -l < "$premium_coverage_rows" | tr -d ' ')"
echo
echo "== Premium Expansion Coverage =="
if [[ "$premium_pack_count" == "0" ]]; then
    echo "- No premium expansion packs found."
else
    while IFS=$'\t' read -r filename title total easy medium hard; do
        [[ -z "$filename" ]] && continue

        echo "- $title ($filename): $total total ($easy easy, $medium medium, $hard hard)"

        if [[ "$total" -ne 40 || "$easy" -ne 14 || "$medium" -ne 13 || "$hard" -ne 13 ]]; then
            echo "  [FAIL] Expected 40 total and 14/13/13 distribution for premium expansions."
            ((errors += 1))
        fi
    done < "$premium_coverage_rows"
fi

if [[ "$errors" -eq 0 ]]; then
    echo "[PASS] All question-pack integrity checks passed."
    exit 0
fi

echo "[FAIL] Audit completed with $errors failing check(s)."
exit 1

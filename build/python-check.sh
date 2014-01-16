#!/bin/sh

PEP8="pep8"
PYFLAKES="pyflakes"
SRCDIR="$(dirname "$0")/.."

cd "${SRCDIR}"

ret=0
FILES="$(
	find build packaging -name '*.py' | grep -v legacy-setup | while read f; do
		[ -e "${f}.in" ] || echo "${f}"
	done
)"

for exe in "${PYFLAKES}" "${PEP8}"; do
	if ! which "${exe}" > /dev/null 2>&1; then
		echo "WARNING: tool '${exe}' is missing" >&2
	else
		"${exe}" ${FILES} || ret=1
	fi
done
exit ${ret}

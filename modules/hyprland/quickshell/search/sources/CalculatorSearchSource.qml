import QtQuick
import Quickshell

Item {
    id: root

    visible: false

    readonly property string sourceId: "calculator"
    readonly property string name: "Calculator"
    readonly property string mode: sourceId
    property string query: ""
    property var results: []
    signal resultsUpdated

    function active(input, forceActive = false): bool {
        return forceActive || input.trim().startsWith("=");
    }

    function setQuery(input, forceActive = false): void {
        query = input;

        if (!active(input, forceActive)) {
            results = [];
            resultsUpdated();
            return;
        }

        const expression = forceActive ? input.trim() : input.trim().slice(1).trim();
        const value = evaluate(expression);

        if (expression.length === 0 || !Number.isFinite(value)) {
            results = [];
            resultsUpdated();
            return;
        }

        const formatted = formatValue(value);
        results = [
            {
                source: root,
                sourceId: root.sourceId,
                title: formatted,
                subtitle: expression,
                iconText: "󰃬",
                score: 0,
                actionText: "Copy",
                value: formatted
            }
        ];
        resultsUpdated();
    }

    function formatValue(value): string {
        if (Math.abs(value - Math.round(value)) < 1e-10)
            return String(Math.round(value));
        return String(Number(value.toPrecision(12))).replace(/\.0+$/, "");
    }

    function evaluate(expression): real {
        let index = 0;

        function skipSpaces() {
            while (index < expression.length && /\s/.test(expression.charAt(index)))
                index++;
        }

        function parseExpression() {
            let value = parseTerm();
            skipSpaces();

            while (index < expression.length) {
                const operator = expression.charAt(index);
                if (operator !== "+" && operator !== "-")
                    break;

                index++;
                const next = parseTerm();
                value = operator === "+" ? value + next : value - next;
                skipSpaces();
            }

            return value;
        }

        function parseTerm() {
            let value = parseFactor();
            skipSpaces();

            while (index < expression.length) {
                const operator = expression.charAt(index);
                if (operator !== "*" && operator !== "/" && operator !== "%")
                    break;

                index++;
                const next = parseFactor();
                if ((operator === "/" || operator === "%") && next === 0)
                    return NaN;
                if (operator === "*")
                    value *= next;
                else if (operator === "/")
                    value /= next;
                else
                    value %= next;
                skipSpaces();
            }

            return value;
        }

        function parseFactor() {
            skipSpaces();

            if (expression.charAt(index) === "+") {
                index++;
                return parseFactor();
            }

            if (expression.charAt(index) === "-") {
                index++;
                return -parseFactor();
            }

            if (expression.charAt(index) === "(") {
                index++;
                const value = parseExpression();
                skipSpaces();
                if (expression.charAt(index) !== ")")
                    return NaN;
                index++;
                return value;
            }

            return parseNumber();
        }

        function parseNumber() {
            skipSpaces();
            const start = index;

            while (index < expression.length && /[0-9.]/.test(expression.charAt(index)))
                index++;

            if (start === index)
                return NaN;

            const raw = expression.slice(start, index);
            if ((raw.match(/\./g) ?? []).length > 1)
                return NaN;

            return Number(raw);
        }

        if (!/^[0-9+\-*/%().\s]+$/.test(expression))
            return NaN;

        const value = parseExpression();
        skipSpaces();
        return index === expression.length ? value : NaN;
    }

    function run(result): void {
        Quickshell.clipboardText = result.value;
    }
}

# Generate thoughts.html
cd $(dirname "$0")

python3 - <<'END' > thoughts.preview.html
import markdown
text = open("./thoughts.txt", 'r')
text = markdown.markdown(text.read().split("\n\n")[0])
print(f"{text}")
END

cat <<EOF > thoughts.html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>slog without the s</title>
    <style>
        html {
            cursor: url(assets/cursor.png), auto;
        }

        body {
            --bg-color: #050211;
            --fg-color: #B5C2B7;
            --dark-fg-color: #8C93A8;
            --primary-color: #FF1B1C;
            --secondary-color: #FF7F11;
            --ternary-color: #A05CE0;

            margin: 40px auto;
            max-width: 650px;
            font-size: 18px;
            color: var(--fg-color);
            padding: 0 10px;
            font-family: 'Lucida Console', 'Helvetica', 'Arial';
            background-color: var(--bg-color);
        }

        h1 {
            text-shadow: 2px 2px var(--dark-fg-color);
        }

        /* Anchors */

        a {
            display: inline-flex;
            color: var(--ternary-color);
            transition: color 0.2s;
            cursor: url(assets/cursor-highlight.png), auto;
        }

        a:hover {
            color: var(--secondary-color);
            filter: drop-shadow(var(--secondary-color) 0px 0px 2px);
        }

        a:active {
            color: var(--primary-color);
            filter: drop-shadow(var(--primary-color) 0px 0px 2px);
        }

        body {
            background-image: url("assets/background.jpeg");
            background-repeat: repeat;
            background-position: center;
        }

        ul {
            padding-left: 0;
        }

        li {
            list-style: none;
        }

        p {
            background-color: var(--bg-color);
            border: 2px dotted var(--ternary-color);
            padding: 8px;
            margin: 0;
            line-height: 1em;
        }
    </style>
</head>

<body>
    <nav>
        <a title="what? too afraid of my dark deep evil fucked up mind? hehe well, *smirks* most ppl are hehe. im just a chill guy" href="../..">go back</a>
    </nav>
    <br>
    <header>
        thoughts I have that I feel the need to externalize.
    </header>
    <main>
        <ul id="ogj-thoughts">
$(python3 - <<'END'
import markdown
text = open("./thoughts.txt", 'r')
for thought in text.read().split("\n\n"):
    print(f"<li>{markdown.markdown(thought)}</li>")
END
)
        </ul>
    </main>
    <footer>
        thoughts are in <a href="thoughts.txt">a txt file</a> that I edit with <a href="ed.sh">a bash script</a>. the txt file uses \n\n to separate thoughts.
    </footer>
</body>
EOF
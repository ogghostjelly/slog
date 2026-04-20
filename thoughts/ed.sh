# Bash script to edit `thoughts.txt` quickly. (uses helix editor)
# I have an alias to it in .bashrc
cd $(dirname "$0")

echo -e "\n\n$(cat thoughts.txt)" > thoughts.txt
hx thoughts.txt
./thoughts.template.sh
git commit -m "thought" thoughts.txt thoughts.preview.html thoughts.html
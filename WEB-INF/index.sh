DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
java -cp "$DIR/lib/alix.jar:$DIR/lib/lucene-core-8.7.0.jar:$DIR/ext/saxon9.jar" alix.cli.Load "$@"
# touch $DIR/web.xml # reload webapp

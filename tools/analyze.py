import sys
from lark import Lark

def main():
    with open('/Users/chadboyd/Documents/GitHub/job-search-automation/qa/tools/powershell.lark', 'r') as f:
        grammar = f.read()

    parser = Lark(grammar)

    with open(sys.argv[1], 'r') as f:
        script = f.read()

    tree = parser.parse(script)
    print(tree.pretty())

if __name__ == '__main__':
    main()

import sys, getopt

def main(argv):
    inputfile = ''
    try:
        opts, args = getopt.getopt(argv,"hi:",["ifile="])
    except getopt.GetoptError:
        print ('test.py -i <inputfile>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print ('test.py -i <inputfile>')
            sys.exit()
        elif opt in ("-i", "--ifile"):
            inputfile = arg
        else:
            print ('test.py -i <inputfile>')
            sys.exit()
            
    with open(inputfile, 'r') as file:
        data = file.read().replace('\n', '')
    print(data)

if __name__ == "__main__":
   main(sys.argv[1:])
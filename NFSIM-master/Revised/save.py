 uds = './node'
    servers = {}
    numNodes = int(sys.argv[1]) #assumes argument is number of nodes to create
    # cast to int
    counter = 0
    while counter < numNodes:
        uds = uds + str(counter) 
        servers[uds] = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        uds = './node'
        counter = counter + 1

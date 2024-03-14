import sys
import serial

def rng(ser):
    sum = 0
    with open('res.out', 'w') as file:
        filtered = []
        while True:
            data = ser.read(1)
            filtered.append(bin(int.from_bytes(data, byteorder="big"))[2:])
            if len(filtered) == 3:
                sum += 3;
                file.write(''.join(filtered))
                file.write('\n')
                filtered = []
            if sum % 3 == 0 :
                print(f'Run : {sum}.')

def xyz_asint(ins):
    filtered = []
    while True:
        data = ser.read(1)
        filtered.append(int.from_bytes(data, byteorder="big"))
        if len(filtered) == 3:
            print(filtered)
            filtered = []

if __name__ == '__main__' :
    args = sys.argv

    port = '/dev/ttyUSB1'
    baudrate = 9600
    test = 'xyz'

    print(args)
    if len(args) == 2 and args[1] == 'd' :
        pass
    if len(args) == 3 and args[1] == 'd' :
        test = args[2]
    elif len(args) < 4 :
        print("port baudrate [xyz, rng].")
        exit(1)
    elif len(args) == 4:
        print(args)
        port = args[1]
        baudrate = int(args[2])
        test = args[3]
    else:
        print("port baudrate [xyz, rng].")
        exit(1)

    ser = serial.Serial(port,baudrate,bytesize=8, stopbits=1, timeout= None)

    if test == 'xyz':
        xyz_asint(ser)
    elif test == 'rng':
        rng(ser)
    else:
        print("port baudrate [xyz, rng].")
        exit(1)

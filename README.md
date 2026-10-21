
### (wip)

# Design


---


## Syntax 

main block <br />
```c
run {
    const string name = "your_name";
    print(hello_world(name, 0));
}
```
<br />

```c
// comment

/*
comment block
*/

```
<br />

loops (unfinished) <br />
```rs

// loop (condition) {}

// in is simply a boolean operator
// so this is the equivalent of for i in a {}
loop (i:=0) in list {
    // automatically iterating, feasable ?
}

// this is somewhat equivalent to a while loop
on: bool = true
loop  on == false {
}

// this is like a normal for loop 
loop (i:=0) < 10 {
    i += 1;
}
```

<br />

functions <br />
```c
fn hello_world(name: string, count: int): () {
    return l
}
```
<br />

lists <br />
```c
// dynamic by default
list l = []
list_add(l, "a")
// etc...
```
<br />

struct <br />
```c 
struct Person {
    age: int,
    name: string.
}

person: Person = {age: 18, name: "name"}

a = person.age

```
<br />

enum <br />
```c
enum Nationality {
    French,
    NotFrench,
}

if n == Nationality.French {}

```
<br />

dictionaries ? <br />
```c
// idk imma think about it

```
<br />

other types <br />
```sh
u32, u64, i32, i63

string
multi line string 

other stuff

```
<br />

Aliasing:
```c
type TypeName: enum {
    // ...
}
type TypeName: struct {
    // ...
}
type TypeName: int
```
<br />

boolean operations <br />
```c 
// joining bools in comparisions ?? idk
if x; > 1 | < 0 { }
if x == (0 | 1 | 2) { }

// normal bools 

if x > 10 {}
```

errors and null <br />
```rs
// declare error names
error none
error input
error something

// use in a variable
number: int | none = none

// use in a function 
fn one_plus_one(): (int | none | something) {
    // stuff 
    // ...
        return int 
    }
    return none 
}
```

polymorphism ? <br />
```rust
fn print(input: any): () {
    match input.type() {
        Int => { convert to string and print }
        string => { print }
        char => whatever
    }
}

```

<br />

markers (idea only) <br />
```c 
@debug "message {some_variable_name}" 
// stops the code at this point and prints (only usable in run {} block)

@log Name "value ?"
// a value assigned to an identifier that can be declared anywhere and can be called inside the run {}
// mayhaps for printing or showing code related data, during debug builds ... ?
```

## Memory Management

- Manual

## Standard Library

- Input/output operations  
- Math and string utilities  
- File and system tools  
- Hashmaps
- FFI
- Vulkan interface

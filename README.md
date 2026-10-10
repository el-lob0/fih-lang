
### (wip)

# Design


---


## Syntax (Grammar)

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

loops <br />
```rs

loop (i32: i = 0) < n {

}

loop (bool: on) == false {

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

if n == Nationality::French {}

```
<br />

maps <br />
```c
// each field is a list (dynamic array)
map People {
    age: int,
    name: string,
}

people: People // initialized each list as empty

people.age = some_list

list_add(people.age, 18)

```
<br />

other types <br />
```sh
u32, u64, i32, i63

string

id // index

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
// joining bools in comparisions

if x; > 1 | < 0 { }

// normal bools 

if x > 10 {}
```

errors <br />
```c 
// to replace magic numbers with human readable and easily send error messages

type error_domain_name: Error {
    FileError(msg),
    InputError(msg),
    // etc... 
    // Enum values start at 1
    // explicitly return None if no error, and None = 0
}

// use in a function 

fn one_plus_one(): int, error_domain_name {
    return 1+1, FileError("pythagore said nah")
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

- Mutable values are moved, pointers are only for immutable values (Cloning/copying is possible).
- All values are freed at the end of their scope.
- You can create, modify and access global data through maps, and indexes/handles.

## Standard Library

- Input/output operations  
- Math and string utilities  
- File and system tools  
- Hashmaps
- FFI
- Vulkan interface

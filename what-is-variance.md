# Variance

We have a function that takes two string slices.
```rust
fn foo<'a>(x: &'a str, y: &'a str) {}
```
and we call that function with a short-lived string and a static string.
```rust
let s = String::new();
foo("", &s);
// 's' dropped here 
```
Let's write this with some fake syntax I made up for illustrative purposes.
```rust
foo(&'static x, &'local y);
```
When resolving the lifetime 'a, a naive borrow checker would see that 'static != 'local and refuse to compile.

But this is valid code! We'd like the borrow checker to realize that a &'static string can shrink to a &'local str.

# Covariance
When a lifetime can shrink to fit
```rust
fn foo<'a>(x: &'a str, y: &'a str) {}
foo(&'static x, &'local y);
```
'static can become 'local because 'static is a subtype of 'local

In type theory "is a subtype of" is represented with the sigil `<:` so `'long <: 'short`. Its like inheritance. A Cat can do anything an Animal can do, and more, because Cat is an Animal. 'long can do anything 'short can do, and more, because 'long contains 'short.

If a lifetime is a subtype of another lifetime, it's safe shrink it.

# Invariance
When a lifetime cannot change
```rust
fn foo<'a>(x: &mut &'a str, y: &'a str) {
    *a = b;
}
// Oh no! Setting a 'static to a 'local!
foo(&mut &'static x, &'local y)
```
See the issue? We want the compiler to reject this. 

We want to say "when using &mut T, the lifetime of T can't change.". This is called invariance. We say &mut T is invariant over T. 

In our code example, `&mut &'static str` is invariant over `&'static str`. `&'static str` can't change, and the compiler refuses to compile it.

> [!NOTE] Borrows are generic
> &T has two generic parameters, imagine it as Borrow<'a, T>:
> &'a T is covariant over 'a and covariant over T. In other words, 'a can change and T can change.
> 
> &mut T has two generic parameters, imagine it as BorrowMut<'a, T>:
> &'a mut T is covariant over 'a but invariant over T. In other words, 'a can change but T can't.

# Contravariance
When a lifetime can grow to fit. The opposite of covariance. Only ever used in function parameters
Fn('short) <: Fn('long)
```rust
fn foo(f: fn(x: &'static str)) {}
fn bar(x: &'local str) {}
foo(bar);
```
If bar can handle a &'local str then it can handle a &'static str.

> [!NOTE]
> Fn(T) -> U is contravariant over T and covariant over U

# Multiplication Rules

In Fn(Fn(T)) what is the variance of T? Variance follows multiplication rules, where covariance = 1, invariance = 0, and contravariance = -1.

In Fn(Fn(T)), T is contravariant twice, -1 * -1 = 1, Fn(Fn(T)) is covariant over T.
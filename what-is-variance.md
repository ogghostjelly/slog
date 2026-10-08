Load this into your favourite markdown viewer. It's in the spirit of code soup! It's definitely not just me being lazy!

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
When resolving the lifetime `'a`, a naive borrow checker would see that `'static` != `'local` and refuse to compile.

But this is valid code! We'd like the borrow checker to realize that a `&'static str` can shrink to a `&'local str`.

# Covariance
When a lifetime can shrink to fit. `'long <: 'short`
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

Is this example valid Rust?
```rust
foo(&mut &'local x, &'static y)
```
Yes! Even though `'local` is invariant, `'static` is covariant, so `'static` can shrink to fit.

# Contravariance
When a lifetime can grow to fit. `Fn('short) <: Fn('long)`

The opposite of covariance. Only ever used in function parameters.
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

# `fn(&'a ()) -> &'a ()`

This ones a bit obscure, I've only ever seen this in `std::task::Context` but I feel the need to explain it anyway.

If we have the type
```rust
type F<'a> = fn(&'a ()) -> &'a ()
```

The contravariant function argument `fn(&'a ())` requires that `F<'short> <: F<'long>`.

The covariant return type `-> &'a ()` requires that `F<'long> <: F<'short>`

Both requirements `F<'short> <: F<'long>` and `F<'long> <: F<'short>` combine to make `F<'a>` invariant.

In the source code for `std::task::Context`
```rust
struct Context<'a> {
    ...
    _marker: PhantomData<fn(&'a ()) -> &'a ()>,
    ...
}
```
This makes `Context<'a>` invariant over `'a`.

This is almost the same as `*mut &'a ()` because `*mut T` is invariant over `T`.
```rust
struct Context<'a> {
    ...
    _marker: PhantomData<*mut &'a ()>,
    ...
}
```
But `*mut T` affects how auto traits are implemented (e.g `Send`/`Sync`), which is why it's not used.
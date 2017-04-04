
sub __deep_clone(|c) {
    c
}

multi sub deep-clone(%hash) is export {
    %hash>>.&__deep_clone;
}

multi sub deep-clone(@array) is export {
    @array>>.&__deep_clone;
}

multi sub deep-clone($scalar) is export {
    __deep_clone($scalar);
}

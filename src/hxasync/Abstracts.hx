package hxasync;

abstract Awaitable<T>(T) from T {}


abstract NoReturn(Dynamic) {
  inline public function new(value: Dynamic) {
    this = null;
  }
}

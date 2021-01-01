package hxasync;


abstract NoReturn(Dynamic) {
  inline public function new(value: Dynamic) {
    this = null;
  }
}

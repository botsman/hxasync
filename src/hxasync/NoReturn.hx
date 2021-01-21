package hxasync;


abstract NoReturn(Dynamic) to Dynamic from Dynamic {
  inline public function new(value: Dynamic) {
    this = null;
  }
}

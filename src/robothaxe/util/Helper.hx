package robothaxe.util;
class Helper {

    inline public static function getQualifiedClassName(o: Dynamic): String {
        return Type.getClassName(Type.getClass(o));
    }

    public function new() {
    }
}

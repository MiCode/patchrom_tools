public class Log {
    public static void i(String info){
        System.out.println(info);
    }

    public static void i(String tag, String info){
        System.out.println( String.format("INFO[%s]: %s", tag, info));
    }

    public static void e(String tag, String err){
        System.err.println( String.format("ERROR[%s]: %s", tag, err));
    }

    public static void w(String tag, String err){
        System.err.println( String.format("WARING[%s]: %s", tag, err));
    }

    public static void e(String err){
        System.err.println(err);
    }
}

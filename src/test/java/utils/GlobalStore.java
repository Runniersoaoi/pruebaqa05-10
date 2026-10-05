package utils;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public final class GlobalStore {

    private static final GlobalStore INSTANCE = new GlobalStore();

    private final Map<String, Object> datos = new ConcurrentHashMap<>();

    private GlobalStore() {
        // Singleton: la instancia se obtiene con getInstance()
    }

    public static GlobalStore getInstance() {
        return INSTANCE;
    }

    public void set(String clave, Object valor) {
        if (valor == null) {
            datos.remove(clave);
        } else {
            datos.put(clave, valor);
        }
    }

    public Object get(String clave) {
        return datos.get(clave);
    }

    public String getString(String clave) {
        Object valor = datos.get(clave);
        return valor == null ? null : String.valueOf(valor);
    }

    public double getDouble(String clave) {
        Object valor = datos.get(clave);
        if (valor == null) {
            throw new IllegalStateException("No existe el valor '" + clave
                    + "' en el store global. Revisa que el Escenario 1 se haya ejecutado primero.");
        }
        if (valor instanceof Number) {
            return ((Number) valor).doubleValue();
        }
        return Double.parseDouble(String.valueOf(valor));
    }

    public boolean has(String clave) {
        return datos.containsKey(clave);
    }

    public Map<String, Object> snapshot() {
        return new LinkedHashMap<>(datos);
    }

    public void clear() {
        datos.clear();
    }

    @Override
    public String toString() {
        return "GlobalStore" + datos;
    }
}

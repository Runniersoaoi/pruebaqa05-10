package runner;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ExamenRunnerTest {

    @Test
    void ejecutarSuiteDelExamen() {

        Results resultados = Runner.path(
                        "classpath:features/regresion.feature",
                        "classpath:features/administrador.feature")
                .outputCucumberJson(true)
                .reportDir("target/karate-reports")
                .parallel(1);

        assertEquals(0, resultados.getFailCount(), resultados.getErrorMessages());
    }
}

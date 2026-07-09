package edu.ucm.usuarios.exception;


import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(value = HttpStatus.INTERNAL_SERVER_ERROR)
public class CsvIOException  extends RuntimeException {

    public CsvIOException() {
        super();
    }

    public CsvIOException(String message) {
        super(message);
    }

    public CsvIOException(Throwable cause) {
        super(cause);
    }
}

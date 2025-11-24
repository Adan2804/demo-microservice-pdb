package com.example.demo.infrastructure.adapter.in.web;

import com.example.demo.application.port.in.GetGreetingUseCase;
import com.example.demo.domain.model.Greeting;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.server.ServerRequest;
import org.springframework.web.reactive.function.server.ServerResponse;
import reactor.core.publisher.Mono;

@Component
public class GreetingHandler {

    private final GetGreetingUseCase getGreetingUseCase;

    public GreetingHandler(GetGreetingUseCase getGreetingUseCase) {
        this.getGreetingUseCase = getGreetingUseCase;
    }

    public Mono<ServerResponse> hello(ServerRequest request) {
        return getGreetingUseCase.getPublicGreeting()
                .flatMap(greeting -> ServerResponse.ok()
                        .contentType(MediaType.APPLICATION_JSON)
                        .bodyValue(greeting));
    }

    public Mono<ServerResponse> secureData(ServerRequest request) {
        return getGreetingUseCase.getSecureGreeting()
                .flatMap(greeting -> ServerResponse.ok()
                        .contentType(MediaType.APPLICATION_JSON)
                        .bodyValue(greeting));
    }
}

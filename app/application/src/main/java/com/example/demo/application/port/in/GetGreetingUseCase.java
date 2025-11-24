package com.example.demo.application.port.in;

import com.example.demo.domain.model.Greeting;
import reactor.core.publisher.Mono;

public interface GetGreetingUseCase {
    Mono<Greeting> getPublicGreeting();
    Mono<Greeting> getSecureGreeting();
}

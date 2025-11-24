package com.example.demo.application.service;

import com.example.demo.application.port.in.GetGreetingUseCase;
import com.example.demo.domain.model.Greeting;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.time.Duration;

@Service
public class GreetingService implements GetGreetingUseCase {

    @Override
    public Mono<Greeting> getPublicGreeting() {
        String version = System.getenv().getOrDefault("APP_VERSION", "v1");
        return Mono.just(new Greeting("Hello from Hexagonal Multi-Module Public Endpoint! Version: " + version));
    }

    @Override
    public Mono<Greeting> getSecureGreeting() {
        return Mono.just(new Greeting("This is SECURE data from Hexagonal Multi-Module Service!"))
                .delayElement(Duration.ofMillis(100));
    }
}

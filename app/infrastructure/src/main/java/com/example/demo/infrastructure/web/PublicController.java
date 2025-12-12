package com.example.demo.infrastructure.web;

import com.example.demo.application.service.GreetingService;
import com.example.demo.domain.model.Greeting;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/public")
public class PublicController {

    private final GreetingService greetingService;

    public PublicController(GreetingService greetingService) {
        this.greetingService = greetingService;
    }

    @GetMapping("/hello")
    public Mono<Greeting> hello() {
        return greetingService.getPublicGreeting();
    }
}

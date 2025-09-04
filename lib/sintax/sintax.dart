import 'package:rxdart/rxdart.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';

extension StreamToOption<T> on BehaviorSubject<T> {
  Option<T> toOption()  => hasValue ? Some(value) : None();
}

extension AnyToBehaviorSubject<T> on T {
  operator >>(BehaviorSubject<T> value) => value.sink.add(this);
}

extension ExceptionToBehaviorSubject<T> on Exception {
  operator >>(BehaviorSubject<T> value) => value.sink.addError(this);
}

extension FormattedMessage on Exception {
  String get getMessage =>

      switch(this) {
        PlatformException ex => "${ex.message}",
        _ =>
        toString().startsWith("Exception: ")
            ? toString().substring(11)
            : toString()
      };

}

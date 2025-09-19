
import 'package:dartz/dartz.dart';
import 'package:flutils/misc/app_get.dart';
import 'package:flutils/types/flutils_navigator.dart';
import 'package:flutils/types/flutils_style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutils/components/widget.dart';

typedef WidgetStreamBuilder<T> = Widget Function(T);
typedef WidgetWrapperBuilder = Widget Function(Widget widget);

extension AnyToWidgetData<T> on T {

  WidgetData<T> get toWidgetDate => WidgetData.fromValue(this);

}

enum WidgetState {
  loading, done
}

class WidgetData<T> {
  T? value;
  final WidgetState state;

  WidgetData({
    this.value,
    this.state = WidgetState.done
  });

  bool get empty => value == null || value is List && (value as List).isEmpty;

  bool get nonEmpty => !empty;

  bool get loading => state == WidgetState.loading;

  T get safe => value!;

  factory WidgetData.fromValue(T value) => WidgetData(value: value);

  factory WidgetData.loading() => WidgetData(state: WidgetState.loading);
}

class WidgetStream<T> extends StatefulWidget {

  final Stream<WidgetData<T>> stream;
  final WidgetStreamBuilder<WidgetData<T>> builder;
  final WidgetData<T>? initialData;
  final Widget? loader;
  final Function? runAgain;
  final String? action;
  final bool showEmptyMessage;
  final Widget? emptyWidget;
  final String emptyMessage;
  final bool ignoreLoading;
  final FlutilsStyle style;
  final FlutilsNavigator navigator;
  final WidgetWrapperBuilder? widgetWrapperBuilder;
  final bool Function(WidgetData<T>)? filter;

  WidgetStream({
    Key? key,
    required this.stream,
    required this.builder,
    this.initialData,
    this.loader,
    this.runAgain,
    this.action,
    this.showEmptyMessage = true,
    this.emptyWidget,
    this.emptyMessage = "Nenhum dado encontrado",
    this.ignoreLoading = false,
    this.widgetWrapperBuilder,
    this.filter,
    required this.style,
    required this.navigator
  }) : super(key: key);

  @override
  State<WidgetStream<T>> createState() => _WidgetStreamState();
}

class _WidgetStreamState<T> extends State<WidgetStream<T>> {


  @override
  Widget build(BuildContext context) {
    return _make();
  }

  Widget _makeErrorBox(Object? error) {
    return WidgetUtil.createErrorBox(
        "$error",
        context,
        widget.style,
        widget.navigator,
        error: error,
        action: widget.action,
        runAgain: widget.runAgain);
  }

  StreamBuilder<WidgetData<T>> _make() {
    return StreamBuilder(
        initialData: widget.initialData,
        stream: AppGet.get(widget.stream),
        builder: (BuildContext context, AsyncSnapshot<WidgetData<T>> snapshot){

          final widgetWrapper = Option.of(widget.widgetWrapperBuilder);

          if(snapshot.hasError){
            final wr = _makeErrorBox(snapshot.error);
            return widgetWrapper.map((f) => f(wr)).or(wr);
          }
          switch(snapshot.connectionState){
            case ConnectionState.waiting:

              final loaderW = widget.loader ?? WidgetUtil.createProgressBox();
              return widgetWrapper.map((f) => f(loaderW)).or(loaderW);

            default:
              if(snapshot.data == null && widget.showEmptyMessage){
                final w = widget.emptyWidget ?? WidgetUtil.createEmptyList(widget.style, text: widget.emptyMessage);
                return widgetWrapper.map((f) => f(w)).or(w);
              }else{
                var sd = snapshot.data as WidgetData<T>;

                if(sd.loading){

                  if(widget.ignoreLoading){
                    if(widget.builder != null) {
                      return widget.builder!(sd);
                    }
                  }

                  final loaderW = widget.loader ?? WidgetUtil.createProgressBox();
                  return widgetWrapper.map((f) => f(loaderW)).or(loaderW);
                }

                if(sd.empty && widget.showEmptyMessage){
                  final emptyW = widget.emptyWidget ?? WidgetUtil.createEmptyList(widget.style, text: widget.emptyMessage);
                  return widgetWrapper.map((f) => f(emptyW)).or(emptyW);
                }

                if(widget.filter != null){
                  if(widget.filter!(sd)){
                    return widget.builder(sd);
                  }
                  return Container();
                } else {
                  return widget.builder(sd);
                }
              }
          }
        }
    );
  }
}
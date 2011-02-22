/*
Helper for extended classes (not needed with ::extension)
When needing to create new instances (of any class), we may need to use an extended class, 
instead of the "normal" class. The factory takes two arguments :
- an object, whose class may implement xxxFactory methods
- a default factory, whose name xxx will be used to get the method's name to call : xxxFactory
If no xxxFactory method is found on the class, then the default factory is returned. 

Ex :
methodFactory = Object.factory(self, .Method)
where self is an instance of ExtendedString.
If ExtendedString has a method "MethodFactory" then the factory will be the value returned 
by this method (ex : ExtendedMethod).
*/

::routine Object.factory public
    use strict arg object, factory
    factoryName = factory~id"Factory"
    if object~class~hasMethod(factoryName) then factory = object~class~send(factoryName)
    return factory

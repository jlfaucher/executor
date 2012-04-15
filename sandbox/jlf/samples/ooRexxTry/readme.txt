Adaptation of ooRexxTry.rxj delivered in BSF4ooRexx (http://sourceforge.net/projects/bsf4oorexx) :
- Preload the same packages as ooRexxShell.
- Support for final '='. Given the multiline input of ooRexxTry.rxj, the support is
  managed at the clause level.

Ex :
c= {::coactivity
    properties=.bsf4rexx ~System.class ~getProperties  -- get the System properties
    enum=properties~propertyNames    -- get an enumeration of the property names

    do while enum~hasMoreElements    -- loop over enumeration
        key=enum~nextElement          -- get next element
        value = properties~getProperty(key)
    .yield[.array~of(key, value)]
    end
   }
c~do=
c~do=

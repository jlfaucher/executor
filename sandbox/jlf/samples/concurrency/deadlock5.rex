/*
An example of deadlock, and how to avoid it.

We have a deadlock because .Closure~variables is guarded.
The generator g is running, the variableDictionnary V37 is locked by the task T2.
The method .Closure~variables is running in the task T1, and is blocked.

Fixed by declaring .Closure~variables unguarded.
*/

g=1~generate.upto(10)
say g~()           -- 1
say g~executable~variables -- deadlock
g~end

--::options trace i
::requires "extension/extensions.cls"


/***************************************************************
Code review
****************************************************************
Thread T1 Activity A106 is blocked on variable dictionnary V37
This is when entering in method .Closure~variables which is guarded

The other thread having a lock on V37 is
Thread T2 Activity A98
This is the method .Closure~DO which is blocked by .yield


#0	0x00007fff7a7e0a16 in __psynch_cvwait ()
#1	0x00007fff7a9a9589 in _pthread_cond_wait ()
#2	0x0000000103e43855 in SysSemaphore::wait(char const*, int)
#3	0x0000000103defee4 in RexxActivity::waitReserve(RexxObject*)
#4	0x0000000103dc33e4 in RexxVariableDictionary::reserve(RexxActivity*)
#5	0x0000000103dad47a in RexxActivation::run(RexxObject*, RexxString*, RexxArray*, RexxObject**, unsigned long, unsigned long, RexxInstruction*, ProtectedObject&)


void SysSemaphore::wait(const char *ds, int di)
{
    int rc;
    int schedpolicy, i_prio;
    struct sched_param schedparam;

    pthread_getschedparam(pthread_self(), &schedpolicy, &schedparam);
    i_prio = schedparam.sched_priority;
    schedparam.sched_priority = 100;
    pthread_setschedparam(pthread_self(),SCHED_OTHER, &schedparam);
    rc = pthread_mutex_lock(&(this->semMutex));      // Lock access to semaphore

    if (this->postedCount == 0)                      // Has it been posted?
    {
        rc = pthread_cond_wait(&(this->semCond), &(this->semMutex)); // Nope, then wait on it.      <--
    }


called by


void RexxActivity::waitReserve(RexxObject *resource )
{
    runsem.reset();                      // clear the run semaphore
    this->waitingObject = resource;      // save the waiting resource
    releaseAccess();                     // release the kernel access
    runsem.wait("RexxActivity::waitReserve", 0); // wait for the run to be posted   <--
    requestAccess();                     // reaquire the kernel access
}


called by


RexxVariableDictionary::reserve
we are in the case 'locked by another activity'
    ...
    else
    {
        this->reservingActivity->checkDeadLock(activity);
        if (this->waitingActivities == OREF_NULL)
        {
            // get a waiting queue
            OrefSet(this, this->waitingActivities, new_list());
        }
        // add to the wait queue
        this->waitingActivities->addLast((RexxObject *)activity);
        // ok, now we wait
        activity->waitReserve((RexxObject *)this);                                  <--
    }


called by


RexxActivation::run
                ...
                if (isGuarded())
                {
                    // get the object variables
                    this->settings.object_variables = this->receiver->getObjectVariables(this->scope);

                    // For proper diagnostic in case of deadlock, do the trace now
                    if (tracingAll() && isMethodOrRoutine())
                    {
                        traceEntry();
                        traceEntryDone = true;
                    }

                    // reserve the variable scope
                    this->settings.object_variables->reserve(this->activity);       <--
                    // and remember for later
                    this->object_scope = SCOPE_RESERVED;
                }

*/

#/*----------------------------------------------------------------------------*/
#/*                                                                            */
#/* Copyright (c) 2014-2014 Rexx Language Association. All rights reserved.    */
#/*                                                                            */
#/* This program and the accompanying materials are made available under       */
#/* the terms of the Common Public License v1.0 which accompanies this         */
#/* distribution. A copy is also available at the following address:           */
#/* http://www.oorexx.org/license.html                                         */
#/*                                                                            */
#/* Redistribution and use in source and binary forms, with or                 */
#/* without modification, are permitted provided that the following            */
#/* conditions are met:                                                        */
#/*                                                                            */
#/* Redistributions of source code must retain the above copyright             */
#/* notice, this list of conditions and the following disclaimer.              */
#/* Redistributions in binary form must reproduce the above copyright          */
#/* notice, this list of conditions and the following disclaimer in            */
#/* the documentation and/or other materials provided with the distribution.   */
#/*                                                                            */
#/* Neither the name of Rexx Language Association nor the names                */
#/* of its contributors may be used to endorse or promote products             */
#/* derived from this software without specific prior written permission.      */
#/*                                                                            */
#/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS        */
#/* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT          */
#/* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS          */
#/* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   */
#/* OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,      */
#/* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED   */
#/* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,        */
#/* OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY     */
#/* OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    */
#/* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS         */
#/* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.               */
#/*                                                                            */
#/*----------------------------------------------------------------------------*/

#/*----------------------------------------------------------------------------*/
#/* Global settings                                                            */
#/*----------------------------------------------------------------------------*/
cmake_minimum_required (VERSION 2.8.12...99.99)

# Policy CMP0069 is not set: INTERPROCEDURAL_OPTIMIZATION is enforced when enabled.
# The ``OLD`` behavior for this policy is to add IPO flags only for Intel compiler on Linux.
# The ``NEW`` behavior for this policy is to add IPO flags for the current compiler or produce an error if CMake does not know the flags.
# To use check_ipo_supported(), policy CMP0069 must be set to NEW; otherwise, a fatal error will occur.
cmake_policy(SET CMP0069 NEW)

#/*----------------------------------------------------------------------------*/
#/* Project settings                                                           */
#/*----------------------------------------------------------------------------*/
project (callrxwn)

#################### callrxwn (executable) #########################
# Sources for callrxwn
add_executable(callrxwn WIN32
    ${PROJECT_SOURCE_DIR}/callrxwn.c
    ${PROJECT_SOURCE_DIR}/callrxwn.rc
    ${PROJECT_SOURCE_DIR}/callrxwn.ico)
# Include file definition
target_include_directories(callrxwn PUBLIC
            ${build_api_dir}
            ${build_api_platform_dir})
# Extra link library definitions
target_link_libraries(callrxwn rexx)
install(TARGETS callrxwn RUNTIME COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/api/callrxwn)
install(FILES ${PROJECT_SOURCE_DIR}/callrxwn.c COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/api/callrxwn)
install(FILES ${PROJECT_SOURCE_DIR}/callrxwn.h COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/api/callrxwn)
install(FILES ${PROJECT_SOURCE_DIR}/callrxwn.ico COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/api/callrxwn)
install(FILES ${PROJECT_SOURCE_DIR}/callrxwn.mak COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/api/callrxwn)
install(FILES ${PROJECT_SOURCE_DIR}/callrxwn.rc COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/api/callrxwn)
install(PROGRAMS ${PROJECT_SOURCE_DIR}/backward.fnc COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/api/callrxwn)

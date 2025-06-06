#/*----------------------------------------------------------------------------*/
#/*                                                                            */
#/* Copyright (c) 2014-2021 Rexx Language Association. All rights reserved.    */
#/*                                                                            */
#/* This program and the accompanying materials are made available under       */
#/* the terms of the Common Public License v1.0 which accompanies this         */
#/* distribution. A copy is also available at the following address:           */
#/* https://www.oorexx.org/license.html                                        */
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
project (call.example)

#################### callrxnt (executable) #########################
# additional source files required by specific platforms
set (platform_libs ${ORX_SYSLIB_DL})
# Sources for call.example
add_executable(stackOverflow  ${PROJECT_SOURCE_DIR}/stackOverflow.cpp)
# Include file definition
target_include_directories(stackOverflow PUBLIC
            ${build_api_dir}
            ${build_api_platform_dir})
target_link_libraries(stackOverflow rexx rexxapi ${ORX_SYSLIB_DL})

add_executable(runRexxProgram ${PROJECT_SOURCE_DIR}/runRexxProgram.cpp)
# Include file definition
target_include_directories(runRexxProgram PUBLIC
            ${build_api_dir}
            ${build_api_platform_dir})
target_link_libraries(runRexxProgram rexx rexxapi ${ORX_SYSLIB_DL})

target_link_libraries(runRexxProgram rexx rexxapi ${platform_callrxnt_libs})

#install the directory files
install(TARGETS stackOverflow RUNTIME COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/native.api/
	  PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
install(FILES ${PROJECT_SOURCE_DIR}/stackOverflow.cpp COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/native.api
          PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
install(TARGETS runRexxProgram RUNTIME COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/native.api/
	  PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
install(FILES ${PROJECT_SOURCE_DIR}/runRexxProgram.cpp COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/native.api
          PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
install(PROGRAMS ${PROJECT_SOURCE_DIR}/HelloWorld.rex COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/native.api
          PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
install(PROGRAMS ${PROJECT_SOURCE_DIR}/backward.fnc COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/native.api
          PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
install(PROGRAMS ${PROJECT_SOURCE_DIR}/tooRecursiveTrapped.rex COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/native.api
          PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
install(PROGRAMS ${PROJECT_SOURCE_DIR}/tooRecursiveUnhandled.rex COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/native.api
          PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
install(FILES ${PROJECT_SOURCE_DIR}/ReadMe.txt COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/native.api
          PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
if (WIN32)
  install(FILES ${PROJECT_SOURCE_DIR}/Makefile.windows COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/native.api)
else()
  install(FILES ${PROJECT_SOURCE_DIR}/Makefile.linux COMPONENT Samples DESTINATION ${INSTALL_SAMPLES_DIR}/native.api)
endif()

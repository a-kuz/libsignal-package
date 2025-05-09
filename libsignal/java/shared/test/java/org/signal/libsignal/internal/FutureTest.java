//
// Copyright 2023 Signal Messenger, LLC.
// SPDX-License-Identifier: AGPL-3.0-only
//

package org.signal.libsignal.internal;

import static org.junit.Assert.*;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.Arrays;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import org.junit.Test;

public class FutureTest {
  @Test
  public void testSuccessFromRust() throws Exception {
    Future<Integer> future = NativeTesting.TESTING_FutureSuccess(1, 21);
    assertEquals(42, (int) future.get());
  }

  @Test
  public void testFailureFromRust() throws Exception {
    Future<Integer> future = NativeTesting.TESTING_FutureFailure(1, 21);
    ExecutionException e = assertThrows(ExecutionException.class, () -> future.get());
    assertTrue(e.getCause() instanceof IllegalArgumentException);
  }

  @Test
  public void testFutureThrowsUnloadedException() throws Exception {
    Future future = NativeTesting.TESTING_FutureThrowsCustomErrorType(1);
    ExecutionException e = assertThrows(ExecutionException.class, () -> future.get());
    assertTrue(e.getCause() instanceof org.signal.libsignal.internal.TestingException);
  }

  @Test
  public void testCapturedStackTraceInException() throws Exception {
    Future future = NativeTesting.TESTING_FutureFailure(1, 21);
    ExecutionException e = assertThrows(ExecutionException.class, () -> future.get());

    Throwable actualStackTrace = e.getCause();

    StringWriter sw = new StringWriter();
    actualStackTrace.printStackTrace(new PrintWriter(sw));
    String stackTraceString = sw.toString();

    String expectedMethodName = new Throwable().getStackTrace()[0].getMethodName();
    String expectedClassName = new Throwable().getStackTrace()[0].getClassName();

    String failureMessage =
        "Stack trace should contain the test method "
            + expectedClassName
            + "."
            + expectedMethodName
            + " \n"
            + "Actual stack trace: \n"
            + stackTraceString;

    assertTrue(
        failureMessage,
        actualStackTrace.getStackTrace().length > 0
            && Arrays.stream(actualStackTrace.getStackTrace())
                .anyMatch(
                    element ->
                        element.getClassName().equals(expectedClassName)
                            && element.getMethodName().contains(expectedMethodName)));
  }
}

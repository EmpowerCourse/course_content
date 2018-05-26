Function Add2(n1, n2)
  Add2 = n1 + n2
End Function

Sub ShowResult(result)
  MsgBox(result)
End Sub

' this will be executed since it is not enclosed in a sub or function when the file is loaded
Dim result
result = Add2(2, 4)
ShowResult(result)

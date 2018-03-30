<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<title>Domänkoll</title>
<img src="Interlanlogga.png" alt=""  border="0" usemap="#head"><br>
<pre>
<form method="post">
<p>Kollar status för DNSSEC, IPv6 och HTTPS på domänen du anger nedan
<input type="text" name="arg" size="40" value="" accept-charset="UTF-8"/>
</p>
<input type="submit" name="submit" value="Go"/>
</form>

<?php
setlocale(LC_CTYPE, "en_US.UTF-8");
if(isset($_POST['arg'])){

  
  $myarg=escapeshellarg($_POST['arg']);
  if($myarg){ 
#    echo "$myarg\n";
    $output=shell_exec("./test.sh $myarg");
    echo "$output\n";
  }

}

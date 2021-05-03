# Benchmark

Difference is pretty negligible after warm-up.
The `MessageExtractor.extract_all_messages/1` function is quite fast.

## System

Benchmark suite executing on the following system:

<table style="width: 1%">
  <tr>
    <th style="width: 1%; white-space: nowrap">Operating System</th>
    <td>Linux</td>
  </tr><tr>
    <th style="white-space: nowrap">CPU Information</th>
    <td style="white-space: nowrap">Intel(R) Core(TM) i7-6700HQ CPU @ 2.60GHz</td>
  </tr><tr>
    <th style="white-space: nowrap">Number of Available Cores</th>
    <td style="white-space: nowrap">8</td>
  </tr><tr>
    <th style="white-space: nowrap">Available Memory</th>
    <td style="white-space: nowrap">7.87 GB</td>
  </tr><tr>
    <th style="white-space: nowrap">Elixir Version</th>
    <td style="white-space: nowrap">1.10.4</td>
  </tr><tr>
    <th style="white-space: nowrap">Erlang Version</th>
    <td style="white-space: nowrap">23.0.3</td>
  </tr>
</table>

## Configuration

Benchmark suite executing with the following configuration:

<table style="width: 1%">
  <tr>
    <th style="width: 1%">:time</th>
    <td style="white-space: nowrap">5 s</td>
  </tr><tr>
    <th>:parallel</th>
    <td style="white-space: nowrap">1</td>
  </tr><tr>
    <th>:warmup</th>
    <td style="white-space: nowrap">2 s</td>
  </tr>
</table>

## Statistics

Run Time
<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Devitation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>
  <tr>
    <td style="white-space: nowrap">only_elixir_modules</td>
    <td style="white-space: nowrap; text-align: right">234.30</td>
    <td style="white-space: nowrap; text-align: right">4.27 ms</td>
    <td style="white-space: nowrap; text-align: right">±20.51%</td>
    <td style="white-space: nowrap; text-align: right">3.93 ms</td>
    <td style="white-space: nowrap; text-align: right">6.74 ms</td>
  </tr>
  <tr>
    <td style="white-space: nowrap">all_modules</td>
    <td style="white-space: nowrap; text-align: right">157.36</td>
    <td style="white-space: nowrap; text-align: right">6.35 ms</td>
    <td style="white-space: nowrap; text-align: right">±14.87%</td>
    <td style="white-space: nowrap; text-align: right">6.05 ms</td>
    <td style="white-space: nowrap; text-align: right">8.58 ms</td>
  </tr>
</table>
Comparison
<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">only_elixir_modules</td>
    <td style="white-space: nowrap;text-align: right">234.30</td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td style="white-space: nowrap">all_modules</td>
    <td style="white-space: nowrap; text-align: right">157.36</td>
    <td style="white-space: nowrap; text-align: right">1.49x</td>
  </tr>
</table>
<hr/>
